cd(@__DIR__)
using Weave
weave("README.jmd", out_path=:pwd, doctype="github")