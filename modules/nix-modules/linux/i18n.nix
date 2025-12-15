{myvars, ...}: {
  time.timeZone = myvars.timezone;
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";
}
