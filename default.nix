{
  lib,
  melpaBuild,
  emacsPackages,
}:
melpaBuild {
  pname = "dashboard-ddnet";
  version = "1.0.0";

  src = ./.;

  packageRequires = with emacsPackages; [
    dashboard
    request
  ];

  meta = {
    homepage = "https://github.com/theobori/dashboard-ddnet";
    description = "Display DDNet player informations on Dashboard";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ theobori ];
  };
}
