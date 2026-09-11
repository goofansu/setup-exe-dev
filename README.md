# setup-exe-dev

## Use as the default exe.dev setup script

```sh
git clone https://github.com/goofansu/setup-exe-dev
cd setup-exe-dev
cat bootstrap.sh | ssh exe.dev defaults write dev.exe new.setup-script
```

`bootstrap.sh` is intentionally small. On first boot it clones this repository into
`/tmp/setup-exe-dev` and executes the full `setup.sh` installer.

To inspect or clear the default:

```sh
ssh exe.dev defaults read dev.exe new.setup-script
ssh exe.dev defaults delete dev.exe new.setup-script
```

## Run directly on an existing VM

```sh
git clone https://github.com/goofansu/setup-exe-dev
cd setup-exe-dev
./setup.sh
```
