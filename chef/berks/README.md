# techcto/berks

Public build image for packaging Chef cookbooks with Berkshelf.

The image intentionally contains only build tooling:

- Chef Workstation, including Berkshelf
- AWS CLI v2
- Basic download/certificate utilities

No project files, credentials, tokens, or private configuration are copied into the image.
