enum SiteType {
  // 🔹 글로벌 사이트
  youtube(["youtube.com", "youtu.be"], ["YouTube", "Video"]),
  instagram(["instagram.com"], ["Instagram", "Social Media"]),
  twitter(["twitter.com", "x.com"], ["Twitter", "Social Media"]),
  github(["github.com"], ["GitHub", "Development"]),
  linkedin(["linkedin.com"], ["LinkedIn", "Professional"]),
  reddit(["reddit.com"], ["Reddit", "Community"]),
  facebook(["facebook.com"], ["Facebook", "Social Media"]),
  tiktok(["tiktok.com"], ["TikTok", "Short Video"]),
  medium(["medium.com"], ["Medium", "Blog"]),
  stackoverflow(["stackoverflow.com"], ["Stack Overflow", "Development"]),
  hackernews(["news.ycombinator.com"], ["Hacker News", "Tech"]),
  devto(["dev.to"], ["Development", "Blog"]),
  twitch(["twitch.tv"], ["Twitch", "Live Streaming"]),
  netflix(["netflix.com"], ["Netflix", "Streaming"]),
  disneyplus(["disneyplus.com"], ["Disney+", "Streaming"]),
  hulu(["hulu.com"], ["Hulu", "Streaming"]),
  googleDrive(["drive.google.com"], ["Google Drive", "Cloud"]),
  dropbox(["dropbox.com"], ["Dropbox", "Cloud"]),
  onedrive(["onedrive.live.com"], ["OneDrive", "Cloud"]),

  // 🔹 글로벌 뉴스 & 쇼핑
  news(["bbc.com", "cnn.com", "nytimes.com", "news.google.com"], ["News"]),
  shopping(["amazon.com", "ebay.com", "aliexpress.com"], ["Shopping"]),
  music(["spotify.com", "soundcloud.com", "music.apple.com"], ["Music"]),

  // 📰 뉴스
  naverNews(["news.naver.com"], ["News"]),
  daumNews(["news.daum.net"], ["News"]),
  joinsNews(["joins.com"], ["News"]),
  haniNews(["hani.co.kr"], ["News"]),
  chosunNews(["chosun.com"], ["News"]),
  dongaNews(["donga.com"], ["News"]),

  // 🔹 한국 사이트 (국가명 삭제)
  // 📢 포털 / 검색
  naver(["naver.com"], ["Naver"]),
  daum(["daum.net"], ["Daum"]),
  zum(["zum.com"], ["Zum"]),

  // 🛒 쇼핑
  gmarket(["gmarket.co.kr"], ["Shopping"]),
  coupang(["coupang.com"], ["Shopping"]),
  elevenst(["11st.co.kr"], ["Shopping"]),
  auction(["auction.co.kr"], ["Shopping"]),

  // 🎮 커뮤니티 & 포럼
  dcinside(["dcinside.com"], ["Community"]),
  clien(["clien.net"], ["Community"]),
  ruliweb(["ruliweb.com"], ["Gaming", "Community"]),
  ppomppu(["ppomppu.co.kr"], ["Community"]),
  fmkorea(["fmkorea.com"], ["Community"]),

  // 🎥 동영상 스트리밍
  tving(["tving.com"], ["tving"]),
  wavve(["wavve.com"], ["wavve"]),
  watcha(["watcha.com"], ["watcha"]),

  // 🎵 음악
  melon(["melon.com"], ["Music"]),
  genie(["genie.co.kr"], ["Music"]),
  bugs(["bugs.co.kr"], ["Music"]),
  flo(["flo.com"], ["Music"]);

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
