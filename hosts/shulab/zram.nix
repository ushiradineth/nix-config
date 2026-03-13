{
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50; # Use up to 50% of RAM for compressed swap
    priority = 100;
  };
}
