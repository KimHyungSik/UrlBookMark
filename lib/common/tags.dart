List<String> generateTags(String url) {
  List<String> tags = [];

  if (url.contains("youtube.com") || url.contains("youtu.be")) {
    tags.add("YouTube");
    tags.add("Video");
  } else if (url.contains("instagram.com")) {
    tags.add("Instagram");
    tags.add("Social Media");
  } else if (url.contains("twitter.com") || url.contains("x.com")) {
    tags.add("Twitter");
    tags.add("Social Media");
  } else if (url.contains("github.com")) {
    tags.add("GitHub");
    tags.add("Development");
  }

  return tags;
}