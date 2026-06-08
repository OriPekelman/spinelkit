# SpinelKit version. Kept in its own file so the gemspec can read it
# without loading the rest of the library (the json/git/log modules pull
# in no deps, but this matches the toy/tep convention exactly).
module SpinelKit
  VERSION = "0.1.1"
end
