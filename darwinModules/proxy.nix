_:
let
  httpProxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
in
{
  networking.proxy = {
    inherit httpProxy;
    httpsProxy = httpProxy;
    allProxy = socksProxy;
  };
}
