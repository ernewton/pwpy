"""
astimage -- generic loading of radio astronomical images

Use `astimage.open (path, mode)` to open an astronomical image,
regardless of its file format.
"""

# Developer notes:
"""
Note that pyrap.images allegedly supports casacore, HDF5, FITS, and
MIRIAD format images transparently. Frankly, I don't trust it, I don't
like the pyrap.images API, and I'd rather not require that casacore
and pyrap be installed.

TODO: for iminfo, need: axis types, ref freq

TODO: standardized celestial axis types for proper generic formatting
of RA/Dec ; glat/glon etc
"""

import numpy as N

from numpy import pi
D2R = pi / 180 # if end up needing more of these, start using astutil.py
R2D = 180 / pi

__all__ = ('UnsupportedError AstroImage MIRIADImage CASAImage '
           'FITSImage SimpleImage open').split ()


class UnsupportedError (RuntimeError):
    def __init__ (self, fmt, *args):
        if not len (args):
            self._message = str (fmt)
        else:
            self._message = fmt % args

    def __str__ (self):
        return self._message


class AstroImage (object):
    path = None
    mode = None
    _handle = None

    shape = None
    "An integer ndarray of the image shape"

    bmaj = None 
    "If not None, the restoring beam FWHM major axis in radians"

    bmin = None 
    "If not None, the restoring beam FWHM minor axis in radians"

    bpa = None 
    """If not None, the restoring beam position angle (east 
    from celestial north) in radians"""

    units = None
    "Lower-case string describing image units (e.g., jy/beam, jy/pixel)"


    def __init__ (self, path, mode):
        self.path = path
        self.mode = mode


    def __del__ (self):
        self.close ()


    def close (self):
        if self._handle is not None:
            self._closeImpl ()
            self._handle = None


    def __enter__ (self):
        return self


    def __exit__ (self, etype, evalue, traceback):
        self.close ()
        return False # raise any exception that may have happened


    def _checkOpen (self):
        if self._handle is None:
            raise UnsupportedError ('this operation cannot be performed on the '
                                    'closed image at "%s"', self.path)


    def _checkWriteable (self):
        if self.mode == 'r':
            raise UnsupportedError ('this operation cannot be performed on the '
                                    'read-only image at "%s"', self.path)


    def read (self, squeeze=False, flip=False):
        raise NotImplementedError ()


    def write (self, data):
        raise NotImplementedError ()


    def toworld (self, pixel):
        raise NotImplementedError ()


    def topixel (self, world):
        raise NotImplementedError ()


    def simple (self):
        lat, lon = self._latlonaxes ()

        if lat < 0 or lon < 0 or lat == lon:
            raise UnsupportedError ('the image "%s" cannot be reduced to a '
                                    'single plane', self.path)

        if lat == 0 and lon == 1 and self.shape.size == 2:
            return self # noop

        return SimpleImage (self, lat, lon)


    def saveCopy (self, path, overwrite=False, openmode=None):
        raise NotImplementedError ()


    def saveAsFITS (self, path, overwrite=False):
        raise NotImplementedError ()


def maybescale (x, a):
    if x is None:
        return None
    return a * x


def maybelower (x):
    if x is None:
        return None
    return x.lower ()


# We use WCSLIB/pywcs for coordinates for both FITS and MIRIAD
# images. It does two things that we don't like. First of all, it
# stores axes in Fortran style, with the first axis being the most
# rapidly varying. Secondly, it does all of its angular work in
# degrees, not radians (why??). We fix these up as best we can.

def _get_wcs_scale (wcs, naxis):
    import pywcs
    wcscale = N.ones (naxis)

    for i in xrange (naxis):
        q = wcscale.size - 1 - i
        text = wcs.wcs.cunit[q].strip ()

        try:
            uc = pywcs.UnitConverter (text, 'rad')
            wcscale[i] = uc.scale
        except SyntaxError: # !!
            pass # not an angle unit; don't futz.

    return wcscale


def _wcs_toworld (wcs, pixel, wcscale, naxis):
    # TODO: we don't allow the usage of "SIP" or "Paper IV"
    # transformations, let alone a concatenation of these, because
    # they're not invertible.

    pixel = N.asarray (pixel)
    if pixel.shape != (naxis, ):
        raise ValueError ('pixel coordinate must be a %d-element vector', naxis)

    pixel = pixel.reshape ((1, naxis))[:,::-1]
    world = wcs.wcs_pix2sky (pixel, 0)
    return world[0,::-1] * wcscale


def _wcs_topixel (wcs, world, wcscale, naxis):
    world = N.asarray (world)
    if world.shape != (naxis, ):
        raise ValueError ('world coordinate must be a %d-element vector', naxis)

    world = (world / wcscale)[::-1].reshape ((1, naxis))
    pixel = wcs.wcs_sky2pix (world, 0)
    return pixel[0,::-1]


def _wcs_latlonaxes (wcs, naxis):
    lat = lon = -1

    if wcs.wcs.lat >= 0:
        lat = naxis - 1 - wcs.wcs.lat
    if wcs.wcs.lng >= 0:
        lon = naxis - 1 - wcs.wcs.lng

    return lat, lon


class MIRIADImage (AstroImage):
    _modemap = {'r': 'rw', # no true read-only option
                'rw': 'rw'
                }

    def __init__ (self, path, mode):
        try:
            from mirtask import XYDataSet
        except ImportError:
            raise UnsupportedError ('cannot open MIRIAD images without the '
                                    'Python module "mirtask"')

        super (MIRIADImage, self).__init__ (path, mode)

        self._handle = h = XYDataSet (path, self._modemap[mode])
        self._wcs, warnings = h.wcs ()

        for w in warnings:
            # Whatever.
            import sys
            print >>sys.stderr, 'irregularity in coordinates of "%s": %s' % (self.path, w)

        naxis = h.getScalarItem ('naxis', 0)
        self.shape = N.empty (naxis, dtype=N.int)
        for i in xrange (naxis):
            q = naxis - i
            self.shape[i] = h.getScalarItem ('naxis%d' % q, 1)

        self.units = maybelower (h.getScalarItem ('bunit'))

        self.bmaj = h.getScalarItem ('bmaj')
        if self.bmaj is not None:
            self.bmin = h.getScalarItem ('bmin', self.bmaj)
            self.bpa = h.getScalarItem ('bpa', 0) * D2R

        self._wcscale = _get_wcs_scale (self._wcs, self.shape.size)


    def _closeImpl (self):
        self._handle.close ()


    def read (self, squeeze=False, flip=False):
        self._checkOpen ()
        nonplane = self.shape[:-2]

        if nonplane.size == 0:
            data = self._handle.readPlane ([], topIsZero=flip)
        else:
            data = N.ma.empty (self.shape, dtype=N.float32)
            data.mask = N.zeros (self.shape, dtype=N.bool)
            n = N.prod (nonplane)
            fdata = data.reshape ((n, self.shape[-2], self.shape[-1]))

            for i in xrange (n):
                axes = N.unravel_index (i, nonplane)
                self._handle.readPlane (axes, fdata[i], topIsZero=flip)

        if squeeze:
            data = data.squeeze ()

        return data


    def write (self, data):
        data = N.ma.asarray (data)

        if data.shape != tuple (self.shape):
            raise ValueError ('data is wrong shape: got %s, want %s' \
                                  % (data.shape, tuple (self.shape)))

        self._checkOpen ()
        self._checkWriteable ()
        nonplane = self.shape[:-2]

        if nonplane.size == 0:
            self._handle.writePlane (data, [])
        else:
            n = N.prod (nonplane)
            fdata = data.reshape ((n, self.shape[-2], self.shape[-1]))

            for i in xrange (n):
                axes = N.unravel_index (i, nonplane)
                self._handle.writePlane (fdata[i], axes)

        return self


    def toworld (self, pixel):
        # self._wcs is still valid if we've been closed, so no need
        # to _checkOpen().

        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)

        return _wcs_toworld (self._wcs, pixel, self._wcscale, self.shape.size)


    def topixel (self, world):
        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)

        return _wcs_topixel (self._wcs, world, self._wcscale, self.shape.size)


    def _latlonaxes (self):
        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)
        return _wcs_latlonaxes (self._wcs, self.shape.size)


    def saveCopy (self, path, overwrite=False, openmode=None):
        import shutil, os.path

        # FIXME: race conditions and such in overwrite checks.
        # Too lazy to do a better job.

        if os.path.exists (path):
            if overwrite:
                if os.path.isdir (path):
                    shutil.rmtree (path)
                else:
                    os.unlink (path)
            else:
                raise UnsupportedError ('refusing to copy "%s" to "%s": '
                                        'destination already exists' % (self.path, path))

        shutil.copytree (self.path, path, symlinks=False)

        if openmode is None:
            return None
        return open (path, openmode)


    def saveAsFITS (self, path, overwrite=False):
        from mirexec import TaskFits
        import os.path

        if os.path.exists (path):
            if overwrite:
                os.unlink (path)
            else:
                raise UnsupportedError ('refusing to export "%s" to "%s": '
                                        'destination already exists' % (self.path, path))

        TaskFits (op='xyout', in_=self.path, out=path).runsilent ()


def _casa_convert (d, unitstr):
    from pyrap.quanta import quantity
    return quantity (d['value'], d['unit']).get_value (unitstr)


class CASAImage (AstroImage):
    def __init__ (self, path, mode):
        try:
            from pyrap.images import image
        except ImportError:
            raise UnsupportedError ('cannot open CASAcore images without the '
                                    'Python module "pyrap.images"')

        super (CASAImage, self).__init__ (path, mode)

        # no mode specifiable
        self._handle = image (path)

        allinfo = self._handle.info ()
        self.units = maybelower (allinfo.get ('unit'))
        self.shape = N.asarray (self._handle.shape (), dtype=N.int)

        ii = self._handle.imageinfo ()

        if 'restoringbeam' in ii:
            self.bmaj = _casa_convert (ii['restoringbeam']['major'], 'rad')
            self.bmin = _casa_convert (ii['restoringbeam']['minor'], 'rad')
            self.bpa = _casa_convert (ii['restoringbeam']['positionangle'], 'rad')

        # Make sure that angular units are always measured in radians,
        # because anything else is ridiculous.

        from pyrap.quanta import quantity
        self._wcscale = wcscale = N.ones (self.shape.size)
        c = self._handle.coordinates ()
        radian = quantity (1., 'rad')

        def getconversion (text):
            q = quantity (1., text)
            if q.conforms (radian):
                return q.get_value ('rad')
            return 1

        i = 0

        for item in c.get_unit ():
            if isinstance (item, basestring):
                wcscale[i] = getconversion (item)
                i += 1
            elif len (item) == 0:
                wcscale[i] = 1 # null unit
                i += 1
            else:
                for subitem in item:
                    wcscale[i] = getconversion (subitem)
                    i += 1


    def _closeImpl (self):
        # No explicit close method provided here. Annoying.
        del self._handle


    def read (self, squeeze=False, flip=False):
        self._checkOpen ()
        data = self._handle.get ()

        if flip:
            data = data[...,::-1,:]
        if squeeze:
            data = data.squeeze ()
        return data


    def write (self, data):
        data = N.ma.asarray (data)

        if data.shape != tuple (self.shape):
            raise ValueError ('data is wrong shape: got %s, want %s' \
                                  % (data.shape, tuple (self.shape)))

        self._checkOpen ()
        self._checkWriteable ()
        self._handle.put (data)
        return self


    def toworld (self, pixel):
        self._checkOpen ()
        pixel = N.asarray (pixel)
        return self._wcscale * N.asarray (self._handle.toworld (pixel))


    def topixel (self, world):
        self._checkOpen ()
        world = N.asarray (world)
        return N.asarray (self._handle.topixel (world / self._wcscale))


    def _latlonaxes (self):
        self._checkOpen ()

        lat = lon = -1
        flat = []

        for item in self._handle.coordinates ().get_axes ():
            if isinstance (item, basestring):
                flat.append (item)
            else:
                for subitem in item:
                    flat.append (subitem)

        for i, name in enumerate (flat):
            # These symbolic names obtained from 
            # casacore/coordinates/Coordinates/DirectionCoordinate.cc
            # Would be nice to have a better system for determining
            # this a la what wcslib provides.
            if name in ('Right Ascension', 'Hour Angle', 'Longitude'):
                if lon == -1:
                    lon = i
                else:
                    lon = -2
            elif name in ('Declination', 'Latitude'):
                if lat == -1:
                    lat = i
                else:
                    lat = -2

        return lat, lon


    def saveCopy (self, path, overwrite=False, openmode=None):
        self._checkOpen ()
        self._handle.saveas (path, overwrite=overwrite)

        if openmode is None:
            return None
        return open (path, openmode)


    def saveAsFITS (self, path, overwrite=False):
        self._checkOpen ()
        self._handle.tofits (path, overwrite=overwrite)


class FITSImage (AstroImage):
    _modemap = {'r': 'readonly',
                'rw': 'update' # ???
                }

    def __init__ (self, path, mode):
        try:
            import pyfits, pywcs
        except ImportError:
            raise UnsupportedError ('cannot open FITS images without the '
                                    'Python modules "pyfits" and "pywcs"')

        super (FITSImage, self).__init__ (path, mode)

        self._handle = pyfits.open (path, self._modemap[mode])
        header = self._handle[0].header
        self._wcs = pywcs.WCS (header)

        self.units = maybelower (header.get ('bunit'))

        naxis = header.get ('naxis', 0)
        self.shape = N.empty (naxis, dtype=N.int)
        for i in xrange (naxis):
            q = naxis - i
            self.shape[i] = header.get ('naxis%d' % q, 1)

        self.bmaj = maybescale (header.get ('bmaj'), D2R)
        self.bmin = maybescale (header.get ('bmin', self.bmaj * R2D), D2R)
        self.bpa = maybescale (header.get ('bpa', 0), D2R)

        self._wcscale = _get_wcs_scale (self._wcs, self.shape.size)


    def _closeImpl (self):
        self._handle.close ()


    def read (self, squeeze=False, flip=False):
        self._checkOpen ()
        data = N.ma.asarray (self._handle[0].data)
        # Are there other standards for expressing masking in FITS?
        data.mask = -N.isfinite (data.data)

        if flip:
            data = data[...,::-1,:]
        if squeeze:
            data = data.squeeze ()
        return data


    def write (self, data):
        data = N.ma.asarray (data)

        if data.shape != tuple (self.shape):
            raise ValueError ('data is wrong shape: got %s, want %s' \
                                  % (data.shape, tuple (self.shape)))

        self._checkOpen ()
        self._checkWriteable ()
        self._handle[0].data[:] = data
        self._handle.flush ()
        return self


    def toworld (self, pixel):
        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)
        return _wcs_toworld (self._wcs, pixel, self._wcscale, self.shape.size)


    def topixel (self, world):
        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)
        return _wcs_topixel (self._wcs, world, self._wcscale, self.shape.size)


    def _latlonaxes (self):
        if self._wcs is None:
            raise UnsupportedError ('world coordinate information is required '
                                    'but not present in "%s"', self.path)
        return _wcs_latlonaxes (self._wcs, self.shape.size)


    def saveCopy (self, path, overwrite=False, openmode=None):
        self._checkOpen ()
        self._handle.writeto (path, output_verify='fix', clobber=overwrite)

        if openmode is None:
            return None
        return open (path, openmod)


    def saveAsFITS (self, path, overwrite=False):
        self.saveCopy (path, overwrite=overwrite)


class SimpleImage (AstroImage):
    def __init__ (self, parent, latax, lonax):
        self._handle = parent
        self._latax = latax
        self._lonax = lonax

        checkworld1 = parent.toworld (parent.shape * 0.) # need float!
        checkworld2 = parent.toworld (parent.shape - 1.) # (for pyrap)
        self._topixelok = True

        for i in xrange (parent.shape.size):
            # Two things to check. Firstly, that all non-lat/lon
            # axes have only one pixel; this limitation can be relaxed
            # if we add a mechanism for choosing which non-spatial
            # pixels to work with.
            #
            # Secondly, check that non-lat/lon world coordinates
            # don't vary over the image; otherwise topixel() will
            # be broken.
            if i in (latax, lonax):
                continue
            if parent.shape[i] != 1:
                raise UnsupportedError ('cannot simplify an image with '
                                        'nondegenerate nonspatial axes')
            if N.abs (1 - checkworld1[i] / checkworld2[i]) > 1e-6:
                self._topixelok = False

        self.path = '<subimage of %s>' % parent.path
        self.shape = N.asarray ([parent.shape[latax], parent.shape[lonax]])
        self.bmaj = parent.bmaj
        self.bmin = parent.bmin
        self.bpa = parent.bpa
        self.units = parent.units

        self._pctmpl = N.zeros (parent.shape.size)
        self._wctmpl = parent.toworld (self._pctmpl)


    def _closeImpl (self):
        pass


    def read (self, squeeze=False, flip=False):
        self._checkOpen ()
        data = self._handle.read (flip=flip)
        idx = list (self._pctmpl)
        idx[self._latax] = slice (None)
        idx[self._lonax] = slice (None)
        data = data[tuple (idx)]

        if self._latax > self._lonax:
            # Ensure that order is (lat, lon). Note that unlike the
            # above operations, this forces a copy of data.
            data = data.T

        if squeeze:
            data = data.squeeze () # could be 1-by-N ...

        return data


    def write (self, data):
        data = N.ma.asarray (data)

        if data.shape != tuple (self.shape):
            raise ValueError ('data is wrong shape: got %s, want %s' \
                                  % (data.shape, tuple (self.shape)))

        self._checkOpen ()
        self._checkWriteable ()

        fulldata = N.ma.empty (self._handle.shape, dtype=data.dtype)
        idx = list (self._pctmpl)
        idx[self._latax] = slice (None)
        idx[self._lonax] = slice (None)

        if self._latax > self._lonax:
            fulldata[tuple (idx)] = data.T
        else:
            fulldata[tuple (idx)] = data

        self._handle.write (fulldata)
        return self


    def toworld (self, pixel):
        self._checkOpen ()
        p = self._pctmpl.copy ()
        p[self._latax] = pixel[0]
        p[self._lonax] = pixel[1]
        w = self._handle.toworld (p)
        world = N.empty (2)
        world[0] = w[self._latax]
        world[1] = w[self._lonax]
        return world


    def topixel (self, world):
        self._checkOpen ()
        if not self._topixelok:
            raise UnsupportedError ('mixing in the coordinate system of '
                                    'this subimage prevents mapping from '
                                    'world to pixel coordinates')

        w = self._wctmpl.copy ()
        w[self._latax] = world[0]
        w[self._lonax] = world[1]
        p = self._handle.topixel (w)
        pixel = N.empty (2)
        pixel[0] = p[self._latax]
        pixel[1] = p[self._lonax]
        return pixel


    def simple (self):
        return self


    def saveCopy (self, path, overwrite=False, openmode=None):
        raise UnsupportedError ('cannot save a copy of a subimage')


    def saveAsFITS (self, path, overwrite=False):
        raise UnsupportedError ('cannot save subimage as FITS')


def open (path, mode):
    import __builtin__
    from os.path import exists, join, isdir

    if mode not in ('r', 'rw'):
        raise ValueError ('mode must be "r" or "rw"; got "%s"' % mode)

    if exists (join (path, 'image')):
        return MIRIADImage (path, mode)

    if exists (join (path, 'table.dat')):
        return CASAImage (path, mode)

    if isdir (path):
        raise UnsupportedError ('cannot infer format of image "%s"' % path)

    with __builtin__.open (path, 'rb') as f:
        sniff = f.read (9)

    if sniff.startswith ('SIMPLE  ='):
        return FITSImage (path, mode)

    raise UnsupportedError ('cannot infer format of image "%s"' % path)
