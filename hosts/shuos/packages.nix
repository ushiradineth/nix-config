{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    firefox
    discord
    bitwarden
    claude-code
    opencloud-desktop
    localsend # AirDrop alternative
    expect # Automate interactive applications
    figma-linux
    notion-app-enhanced
    dust # Disk usage analyzer
    procs # Modern process viewer

    # Qt dependencies for OpenCloud
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtquickcontrols
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtdeclarative
    libsForQt5.qt5.qtsvg
    libsForQt5.qt5.qtwayland
    qt5.qtbase
  ];

  # Set Qt plugin path
  environment.variables = {
    QT_PLUGIN_PATH = "${pkgs.libsForQt5.qt5.qtbase.bin}/lib/qt-5.15.14/plugins";
    QML2_IMPORT_PATH = "${pkgs.libsForQt5.qt5.qtdeclarative.bin}/lib/qt-5.15.14/qml";
  };
}
