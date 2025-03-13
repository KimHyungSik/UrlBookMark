enum SiteType {
  // ===== Global Social Media =====
  youtube(["youtube.com", "youtu.be"], ["YouTube", "Video"]),
  instagram(["instagram.com"], ["Instagram", "Social Media"]),
  twitter(["twitter.com", "x.com"], ["Twitter", "Social Media"]),
  facebook(["facebook.com"], ["Facebook", "Social Media"]),
  tiktok(["tiktok.com"], ["TikTok", "Video"]),
  reddit(["reddit.com"], ["Reddit", "Community"]),

  // ===== Global Video & Streaming =====
  netflix(["netflix.com"], ["Netflix", "Streaming"]),
  disneyPlus(["disneyplus.com"], ["Disney+", "Streaming"]),
  hulu(["hulu.com"], ["Hulu", "Streaming"]),
  twitch(["twitch.tv"], ["Twitch", "Live Streaming"]),

  // ===== Global Development & Tech =====
  github(["github.com"], ["GitHub", "Development"]),
  stackoverflow(["stackoverflow.com"], ["Stack Overflow", "Development"]),
  hackerNews(["news.ycombinator.com"], ["Hacker News", "Tech"]),
  devTo(["dev.to"], ["Development", "Blog"]),
  medium(["medium.com"], ["Medium", "Blog"]),

  // ===== Global Professional =====
  linkedin(["linkedin.com"], ["LinkedIn", "Professional"]),

  // ===== Global Cloud Storage =====
  googleDrive(["drive.google.com"], ["Google Drive", "Cloud"]),
  dropbox(["dropbox.com"], ["Dropbox", "Cloud"]),
  oneDrive(["onedrive.live.com"], ["OneDrive", "Cloud"]),

  // ===== Global News =====
  bbcNews(["bbc.com"], ["BBC", "News"]),
  cnnNews(["cnn.com"], ["CNN", "News"]),
  nytNews(["nytimes.com"], ["New York Times", "News"]),
  googleNews(["news.google.com"], ["Google News", "News"]),

  // ===== Global Shopping =====
  amazon(["amazon.com"], ["Amazon", "Shopping"]),
  ebay(["ebay.com"], ["eBay", "Shopping"]),
  aliexpress(["aliexpress.com"], ["AliExpress", "Shopping"]),

  // ===== Global Music =====
  spotify(["spotify.com"], ["Spotify", "Music"]),
  soundcloud(["soundcloud.com"], ["SoundCloud", "Music"]),
  appleMusic(["music.apple.com"], ["Apple Music", "Music"]),

  // ===== Korean Portals =====
  naver(["naver.com"], ["Naver", "Portal"]),
  daum(["daum.net"], ["Daum", "Portal"]),
  zum(["zum.com"], ["Zum", "Portal"]),

  // ===== Korean News =====
  naverNews(["news.naver.com"], ["Naver News", "News"]),
  daumNews(["news.daum.net"], ["Daum News", "News"]),
  joinsNews(["joins.com"], ["Joins", "News"]),
  haniNews(["hani.co.kr"], ["Hani", "News"]),
  chosunNews(["chosun.com"], ["Chosun", "News"]),
  dongaNews(["donga.com"], ["Donga", "News"]),

  // ===== Korean Shopping =====
  gmarket(["gmarket.co.kr"], ["Gmarket", "Shopping"]),
  coupang(["coupang.com"], ["Coupang", "Shopping"]),
  elevenst(["11st.co.kr"], ["11st", "Shopping"]),
  auction(["auction.co.kr"], ["Auction", "Shopping"]),

  // ===== Korean Communities =====
  dcinside(["dcinside.com"], ["DCinside", "Community"]),
  clien(["clien.net"], ["Clien", "Community"]),
  ruliweb(["ruliweb.com"], ["Ruliweb", "Gaming", "Community"]),
  ppomppu(["ppomppu.co.kr"], ["Ppomppu", "Community"]),
  fmkorea(["fmkorea.com"], ["FMKorea", "Community"]),

  // ===== Korean Streaming =====
  tving(["tving.com"], ["TVING", "Streaming"]),
  wavve(["wavve.com"], ["Wavve", "Streaming"]),
  watcha(["watcha.com"], ["Watcha", "Streaming"]),

  // ===== Korean Music =====
  melon(["melon.com"], ["Melon", "Music"]),
  genie(["genie.co.kr"], ["Genie", "Music"]),
  bugs(["bugs.co.kr"], ["Bugs", "Music"]),
  flo(["flo.com"], ["FLO", "Music"]);

  final List<String> domains;
  final List<String> tags;

  const SiteType(this.domains, this.tags);
}

List<String> generateTags(String url) {
  for (var site in SiteType.values) {
    if (site.domains.any((domain) => url.contains(domain))) {
      return site.tags;
    }
  }
  return [];
}
