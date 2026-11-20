# Blackcomb: make Plasma Wayland reliable in VirtualBox.
# KWin's atomic DRM mode setting and hardware cursor plane are unreliable with
# VMSVGA/vmwgfx; KDE documents legacy DRM mode and a software cursor for VMs.
# This is not safe graphics: modesetting stays enabled and accelerated.
export KWIN_DRM_NO_AMS=1
export KWIN_FORCE_SW_CURSOR=1
