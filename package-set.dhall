let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall sha256:b46f30e811fe5085741be01e126629c2a55d4c3d6ebf49408fb3b4a98e37589b

let Package = { name: Text, repo: Text, version: Text, dependencies: List Text }

let additions = [
  { name = "candy_0_1_9", repo = "https://github.com/aramakme/candy_library.git", version = "v0.1.9", dependencies = ["base"] },
  { name = "candy", repo = "https://github.com/aramakme/candy_library.git", version = "v0.1.9", dependencies = ["base"] },
  { name = "map_8_0_0_alpha_5", repo = "https://github.com/ZhenyaUsenko/motoko-hash-map.git", version = "v8.0.0-alpha.5", dependencies = ["base"] },
  { name = "map", repo = "https://github.com/ZhenyaUsenko/motoko-hash-map.git", version = "v8.0.0-alpha.5", dependencies = ["base"] },
]: List Package

let overrides = []: List Package

in upstream # additions # overrides
