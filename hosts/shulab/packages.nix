{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    gh
    ffmpeg
    yt-dlp
    python3
    chromium
  ];
}
