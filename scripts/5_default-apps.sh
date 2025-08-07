update-desktop-database ~/.local/share/applications

# Open all images with imv
xdg-mime default imv.desktop image/png
xdg-mime default imv.desktop image/jpeg
xdg-mime default imv.desktop image/gif
xdg-mime default imv.desktop image/webp
xdg-mime default imv.desktop image/bmp
xdg-mime default imv.desktop image/tiff

# Open PDFs with Papers
xdg-mime default org.gnome.Papers-previewer.desktop application/pdf

# Use Brave as the default browser
xdg-settings set default-web-browser brave-browser.desktop
xdg-mime default brave-browser.desktop x-scheme-handler/http
xdg-mime default brave-browser.desktop x-scheme-handler/https

# Open video files with Celluloid
xdg-mime default celluloid.desktop video/mp4
xdg-mime default celluloid.desktop video/x-msvideo
xdg-mime default celluloid.desktop video/x-matroska
xdg-mime default celluloid.desktop video/x-flv
xdg-mime default celluloid.desktop video/x-ms-wmv
xdg-mime default celluloid.desktop video/mpeg
xdg-mime default celluloid.desktop video/ogg
xdg-mime default celluloid.desktop video/webm
xdg-mime default celluloid.desktop video/quicktime
xdg-mime default celluloid.desktop video/3gpp
xdg-mime default celluloid.desktop video/3gpp2
xdg-mime default celluloid.desktop video/x-ms-asf
xdg-mime default celluloid.desktop video/x-ogm+ogg
xdg-mime default celluloid.desktop video/x-theora+ogg
xdg-mime default celluloid.desktop application/ogg
