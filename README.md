# Unsloth Studio launchers

`sparkcode`, `sparkpi`, and `sparkcodex` launch OpenCode, Pi, and Codex against the model currently loaded in Unsloth Studio. They query `/v1/models`, select only entries with `loaded: true`, and stop with a clear message if none is loaded.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/alexandermakuch/sparkscripts/main/install.sh | sh
export SPARK_ADDR=192.168.0.70:8888
export SPARK_API_KEY=your-key # UNSLOTH_API_KEY also works
```

Then run `sparkcode`, `sparkpi`, or `sparkcodex`. Each accepts `--effort minimal|low|medium|high|xhigh|max` and defaults to `high`:

```sh
sparkcode --effort max
sparkpi --effort max
sparkcodex --effort max
```

`SPARK_ADDR` accepts `host:port`, a full URL, or a URL ending in `/v1`. Set `SPARK_MODEL` only when more than one model is loaded and you want a specific one. `SPARK_EFFORT` can set the default effort without a flag.

Requires `curl`, `jq`, and whichever agent CLI you use. Set `SPARK_INSTALL_BASE_URL` to install from a fork or another host.
