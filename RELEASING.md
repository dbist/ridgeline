# Releasing Ridgeline

For the maintainer. A release is a signed, annotated tag on a merge commit on
`main`, plus a GitHub release with the `-r` build attached and its SHA-256 in
the notes.

## One-time: a tag-signing key

Tags are signed with an SSH key, so no GPG install is needed:

    git config --global gpg.format ssh
    git config --global user.signingkey ~/.ssh/id_ed25519.pub

For GitHub to show the tag as *Verified*, add the same public key at
*Settings → SSH and GPG keys → New SSH key* with **Key type: Signing Key**.
An authentication key alone is not enough.

To verify signatures locally, list the key as an allowed signer:

    echo "$(git config user.email) $(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/allowed_signers
    git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

## Each release

1. **Build from the commit you will tag.** Use a clean `main` with the PRs
   for the release merged:

       git switch main && git pull --ff-only && git status --short   # expect no output
       SDK=$(cat ~/Library/Application\ Support/Garmin/ConnectIQ/current-sdk.cfg)
       "$SDK/bin/monkeyc" -d enduro3 -f monkey.jungle \
         -o build/Ridgeline.prg -y ~/.garmin/developer_key.der -r

   Load it in the simulator (README, *Build*) before going further.

2. **Record the checksum and size** for the notes:

       shasum -a 256 build/Ridgeline.prg
       wc -c < build/Ridgeline.prg

3. **Tag it, signed and annotated**, then check the signature:

       git tag -s vX.Y.Z -m "Ridgeline vX.Y.Z"
       git tag -v vX.Y.Z
       git push origin vX.Y.Z

4. **Publish the release** with the build attached:

       gh release create vX.Y.Z build/Ridgeline.prg \
         --title "Ridgeline vX.Y.Z" --notes-file notes.md --verify-tag

   The notes follow the earlier releases:
   - a one-line summary;
   - *Install*: replace `GARMIN/APPS/Ridgeline.prg`, and which older
     versions need deleting on the watch first. v1.0.0 has no settings
     menu, so upgrading from it needs a delete. Settings are changed on the
     watch, not in Garmin Connect;
   - the SHA-256 and size from step 2;
   - *What's changed* with PR numbers, then changes that don't affect the
     face;
   - "Built with Connect IQ SDK <version> from <short sha>", and where it
     was checked (simulator, watch).

5. **Check the published asset** matches what you built:

       gh release download vX.Y.Z -p Ridgeline.prg -O - | shasum -a 256

## Versioning

Patch (`1.2.1`) for fixes only. Minor (`1.3.0`) for new features or settings.
Settings are append-only, so a release never renumbers a property value and
upgrades keep the user's settings.
