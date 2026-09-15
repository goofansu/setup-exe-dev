# setup-exe-dev

Clone this repository before using either setup method:

```sh
git clone https://github.com/goofansu/setup-exe-dev
cd setup-exe-dev
```

## Set the default for every new VM

Store `bootstrap.sh` as your exe.dev default setup script:

```sh
cat bootstrap.sh | ssh exe.dev defaults write dev.exe new.setup-script
```

Each new VM runs the script once during its initial setup. The script clones the
latest version of this repository into `/tmp/setup-exe-dev` and runs `setup.sh`.

Inspect or clear the default with:

```sh
ssh exe.dev defaults read dev.exe new.setup-script
ssh exe.dev defaults delete dev.exe new.setup-script
```

## Use once for a single new VM

Create one VM with `bootstrap.sh` without changing your default setup script:

```sh
cat bootstrap.sh | ssh exe.dev new --name my-vm --setup-script /dev/stdin
```

Replace `my-vm` with the name of the VM. The VM runs the script once during its
initial setup.

## Run directly on an existing VM

From a clone of this repository on the VM, run:

```sh
./setup.sh
```
