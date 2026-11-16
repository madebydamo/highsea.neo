# Privacy map categories of the media services (not prefixed: every copy of
# the plugin defines the same values, which merge).
{...}: {
  neoPlugin.modules.privacy = {...}: {
    neo.privacy.categories = {
      movies-tv = {
        label = "Films & TV";
        icon = ./services/jellyfin/icon.svg;
        rank = 140;
        cloud = "Streaming services record what you watch, when, for how long and on which screen, and use it to profile your household.";
        home = "Your films and shows play on every screen and only your own server knows what you watched.";
        examples = ["Netflix" "Disney+" "Prime Video"];
      };
      music = {
        label = "Music";
        icon = ./services/lidarr/icon.svg;
        rank = 141;
        cloud = "Streaming services know what you listen to, when and where, and build a picture of your moods and habits from it.";
        home = "Your library plays everywhere, and only your server knows your taste.";
        examples = ["Spotify" "Apple Music"];
      };
      audiobooks = {
        label = "Audiobooks & podcasts";
        icon = ./services/audiobookshelf/icon.svg;
        rank = 142;
        cloud = "Audiobook and podcast apps record what you listen to and how far you got.";
        home = "Your books and podcasts keep your place on every device, without an account at a store.";
        examples = ["Audible" "Spotify"];
      };
    };
  };
}
