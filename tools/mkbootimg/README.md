# Pinned AOSP Android boot-image writer

Unmodified files from the AOSP mirror:
https://github.com/LineageOS/android_system_tools_mkbootimg/tree/808ecd09666ffe0ff5800f02af693abce56eb395

Included: mkbootimg.py and its import dependency gki/generate_gki_certificate.py.
Both retain their Android Open Source Project copyright and Apache-2.0 headers.
See LICENSE for the license text. GKI signing is not used by our v2 images.
This directory is not a complete GKI signing toolchain.

Run through scripts/mkbootimg.sh. The boot-image build and synthetic packaging
test share that entry point. Ubuntu's mkbootimg 1:34.0.4-1build3 failed in CI
with ModuleNotFoundError: No module named 'gki'; this pinned source avoids the
distribution package's missing Python dependency.
