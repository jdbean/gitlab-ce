import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initSettingsPanels from '~/settings_panels';
import { initDirtySubmitMulti } from '~/dirty_submit';

document.addEventListener('DOMContentLoaded', () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
  initConfirmDangerModal();
});

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();
  initDirtySubmitMulti([
    document.querySelector('.js-general-settings-form'),
    document.querySelector('.js-general-permissions-form'),
  ]);
});
