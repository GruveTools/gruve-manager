# Gruve Client

## Usage

_Backup your `local.conf` before running this script. You may also choose to run `force-local` on your rig to prevent override from a remote config._

To get up and running, you need to do the following:

### Install script

This script will install to `gruve-client` in your home directory, add it to your PATH, and add a cron entry to start it running:

```
curl -o- https://raw.githubusercontent.com/GruveTools/gruve-client/master/install.sh | bash
```

### Alternative manual install

1. First, clone the repository to your rig:
    `git clone https://github.com/GruveTools/gruve-client ~/gruve-client/`

2. Make your configuration directory:
    `mkdir ~/.gruve`

3. Copy the sample config file to your configuration directory:
    `cp ~/gruve-client/config.sample.json ~/.gruve/config.json`

4. Edit your `config.json` to set your preferences. The following options in particular:
    * Set the `whattomine_url` by going to [whattomine.com](https://whattomine.com), using the calulator as per your rig setup, and then copy and pasting the URL, replacing `whattomine.com/coins` with `whattomine.com/coins.json` but leaving the rest the same.
    * Set the various `configs` to refer to config files that you have for the relevant coins, which you should copy into `~/.gruve/configs/`.

5. Setup a crontask to run the autominer script every minute, run `crontab -e` to begin editing and add the following line:
    `* * * * * /home/ethos/gruve-client/gruve-client`

You can also run the script manually, and if you pass `--dry-run` to the script, it won't do any of the miner restarting, _but will still switch configs_.

## Donations

You can send donations to any of the following addresses:

* BTC: `3Ckx1eocUY5fHinbDXZtCGGqwdT1VwGBa4`
* ETH: `0xB06EBE124C5fbb12E4551b1FEF647828D0d1AD74`
* LTC: `LSXfQid4PZcAdgmEpUJXnJWppY7GKZ4uft`
* GAS: `AbuMTAwKgGA4AWduDDEQ9UMBa8gnF5sgT2`

## Credits

This script has been adapted by [Japh](https://github.com/japh) and [neokjames](https://github.com/neokjames).

This script was originally shared by AllCrypto in the YouTube video [How I Mine the Most Profitable Altcoins With ethOS](https://www.youtube.com/watch?v=vf0doK-j54g), with the [snippet](http://textuploader.com/dl3w5) linked in the comments.
