# Changelog


## Unreleased


## Release 0.0.15-alpha

#### Fixed
- Fixed broken pipe with `tail -F`


## Release 0.0.14-alpha

#### Added
- Added feature: Made `PSEStore` instance available to all PSE scripts to persist data, interacti with sockets, stop signal and logger
- Added chat-bot PSE
- Added documentation for PSE API


## Release 0.0.13-alpha

#### Added
- Feature: Client port hopping (`--reconn-robin`): #43


## Release 0.0.12-alpha

#### Added
- Feature: Adedd PSE: Pwncat Scripting Engine (`--script-send` and `--script-recv`): #62


## Release 0.0.11-alpha

#### Fixed
- Fixed various bugs with `--reconn`, `--keep-open`, `--local` and `--remote`
- Fixed various bugs with threads
- Fixed shutdown behaviour with Ctrl+c for --keep-open
- Fixed shutdown behaviour with Ctrl+c for --reconn

#### Added
- Feature: Custom ping word (`--ping-word`): #49
- Python type coverage report
- CI: Added ca. 13,000 LoC integration tests and fixed findings accordingly
- CI: Added dockerized interactive tests to simulate Ctrl+c

#### Changed
- Code: really heavy heavy code refactoring
- Option: `-C`/`--crlf` now takes an argument to either force LF, CRLF or CR or even remove line feeds altogether on input AND output (or keep as it is, if not specified)
- Modularized code for better plugin integration
- Fixes #47 Change `--udp-*` options to `--*` to allow both, UDP and TCP


## Release 0.0.10-alpha

#### Added
- CI: pylinyt
- CI: mypy

#### Changed
- Code: heavy refactoring
- CI: separate jobs
- API: switched from pdoc to pdoc3


## Release 0.0.9-alpha

#### Added
- Feature: colorized logging (`-c`/`--color`): #56


## Release 0.0.8-alpha

#### Added
- Feature: implemented remote port forwarding mode: `-R`/`--remote`


## Release 0.0.7-alpha

#### Fixed
- Fixed `-L`/`--local` mode to now persist multiple requests
- Fixed `-C`/`--crlf` Only replace `\n` with `\r\n` if `\n` exists and don't blindly add.

#### Added
- Integration tests for `L`/`--local` mode

#### Changed
- Plugin architecture has been heavily refactored to make it easier to add new plugins
- Improved logging


## Release 0.0.6-alpha

#### Fixed
- Fixed `-n`/`--nodns` to actually not resolve DNS
- Fixed various threading issues

#### Added
- Check for unimplemented options
- Feature: Made socket receive non-blocking
- Feature: Made stdin non-blocking (except for Windows)
- Documentation: man page
- Documentation: updated readme and contribution guidelines
- CI: lots of integration tests for Linux, MacOS and Windows

#### Changed
- Changed daemon threads to non-daemon threads
- Use Python's `logging` module instead of self-written one
- Usage options have changed drastically
- Changed `--reconn` and `--reconn-wait` to keep open (`-k`/`--keep`)

#### Removed
- Removed `builtins` import for cross-os base install compatibility


## Release 0.0.5-alpha

#### Added
- Feature: Local port forward (`-L`)


## Release 0.0.4-alpha

#### Added
- Feature: UDP connect mode interval ping (`--udp-ping-intvl`) for unbreakable UDP reverse shells


## Release 0.0.3-alpha

#### Fixed
- Hardened Python 2/3 string compatibility
- Checking against mutually exclusive arguments
- Fix crash while checking for Mac newlines `\r`

#### Added
- Editorconfig
- Feature: Re-connect/Re-listen on connection abort (`--reconn`)
- Feature: Re-connect/Re-listen on connection abort (`--reconn-wait`)


## Release 0.0.2-alpha

#### Added
- Feature: Execute shell commands (`-e/--exec`)
- Feature: Skip DNS resolution (`-n/--nodns`)
- Documentation: API docs

#### Changed
- Renamed project from netcat to pwncat


## Release 0.0.1-alpha

#### Added
- Feature: Listen
- Feature: Connect
- Feature: UDP mode
- Feature: Change linefeeds (LF vs CRLF)
- Feature: Verbosity
