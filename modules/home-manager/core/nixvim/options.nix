{...}: {
  programs.nixvim.globals = {
    mapleader = " "; # Set the leader key to space
    maplocalleader = "\\"; # Set the local leader key to backslash
    autoformat = true; # Enable auto formatting on save
  };

  programs.nixvim.opts = {
    expandtab = true; # Use spaces instead of tabs
    tabstop = 2; # A <Tab> in a file = 2 spaces
    softtabstop = 2; # A <Tab> when editing = 2 spaces
    shiftwidth = 2; # Auto-indent uses 2 spaces
    laststatus = 3; # Global statusline
    swapfile = false;
    updatetime = 300; # Makes cursor-hover actions (like diagnostics popups) respond faster

    showmode = false; # set noshowmode
    showcmd = false; # set noshowcmd
    shortmess = "F"; # set shortmess+=F
    fillchars = "vert:▕"; # set fillchars+=vert:▕
    hlsearch = false; # set nohlsearch
    signcolumn = "yes"; # set signcolumn=yes;
  };

  programs.nixvim.extraConfigLua = ''
    -- make :w always silent
    vim.cmd([[cnoreabbrev w silent! write]])
  '';

  programs.nixvim.clipboard = {
    providers = {
      wl-copy.enable = true;
      xsel.enable = true;
    };

    register.__raw = ''vim.env.SSH_TTY and "" or "unnamedplus"'';
  };
}
