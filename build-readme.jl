using Weave
if false
    using Pkg
    cd("c:/git/Game2048Core/")
    Pkg.activate("./weave-env")
end

using Weave
weave("README.jmd", out_path=:pwd, doctype="github")