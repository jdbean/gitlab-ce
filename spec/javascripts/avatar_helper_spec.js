import $ from 'jquery';
import { renderAvatar, renderIdenticon, IDENTICON_BG_COUNT } from '~/helpers/avatar_helper';

describe('avatar_helper', () => {
  describe('renderAvatar', () => {
    it('renders an image with the avatarUrl', () => {
      const avatarUrl = 'https://gitlab.com/not-real-assets/test.png';
      const entity = {
        avatar_url: avatarUrl,
      };

      const result = $(renderAvatar(entity));

      expect(result).toEqual('img');
      expect(result).toHaveAttr('src', avatarUrl);
    });

    it('renders an identicon if no avatarUrl', () => {
      const entity = {
        id: 1,
        name: 'walrus',
      };
      const options = {
        sizeClass: 's16',
      };

      const result = $(renderAvatar(entity, options));

      expect(result).toHaveClass(`identicon ${options.sizeClass} bg2`);
      expect(result.text().trim()).toEqual('W');
    });
  });

  describe('renderIdenticon', () => {
    it('renders with the first letter as title and bg based on id', () => {
      const entity = {
        id: IDENTICON_BG_COUNT + 3,
        name: 'Xavior',
      };
      const options = {
        sizeClass: 's32',
      };

      const result = $(renderIdenticon(entity, options));

      expect(result).toHaveClass(`identicon ${options.sizeClass} bg4`);
      expect(result.text().trim()).toEqual('X');
    });
  });
});
