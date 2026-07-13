pkgname=hid-logitech-dj-bolt-dkms
pkgver=0.1.0
pkgrel=1
pkgdesc="DKMS package for Logitech DJ receiver driver experiments"
arch=(any)
url="https://www.kernel.org/"
license=(GPL2)
depends=(dkms)
source=(
  "hid-logitech-dj.c"
  "hid-logitech-hidpp.c"
  "hid-ids.h"
  "usbhid.h"
  "Makefile"
  "dkms.conf"
)
sha256sums=('SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP'
            'SKIP')

package() {
  local moddir="${pkgdir}/usr/src/${pkgname}-${pkgver}"

  install -d "${moddir}"
  install -d "${moddir}/usbhid"
  install -m644 "${srcdir}/hid-logitech-dj.c" "${moddir}/hid-logitech-dj.c"
  install -m644 "${srcdir}/hid-logitech-hidpp.c" "${moddir}/hid-logitech-hidpp.c"
  install -m644 "${srcdir}/hid-ids.h" "${moddir}/hid-ids.h"
  install -m644 "${srcdir}/usbhid.h" "${moddir}/usbhid/usbhid.h"
  install -m644 "${srcdir}/Makefile" "${moddir}/Makefile"

  sed "s/@PKGVER@/${pkgver}/g" "${srcdir}/dkms.conf" \
    > "${moddir}/dkms.conf"
}
