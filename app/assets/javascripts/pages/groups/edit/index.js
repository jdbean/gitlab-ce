import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initSettingsPanels from '~/settings_panels';
import DirtySubmitCollection from '~/dirty_submit/dirty_submit_collection';

document.addEventListener('DOMContentLoaded', () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
  initConfirmDangerModal();
});

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();
  const dirtySubmitCollection = new DirtySubmitCollection(
    document.querySelectorAll('.js-general-settings-form, .js-general-permissions-form'),
  );
  dirtySubmitCollection.init();
});
