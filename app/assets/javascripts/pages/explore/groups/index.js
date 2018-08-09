import GroupsList from '~/groups_list';
import Landing from '~/landing';
import createGroupTree from '~/groups';

document.addEventListener('DOMContentLoaded', () => {
  new GroupsList(); // eslint-disable-line no-new
  createGroupTree();
  const landingElement = document.querySelector('.js-explore-groups-landing');
  if (!landingElement) return;
  const exploreGroupsLanding = new Landing(
    landingElement,
    landingElement.querySelector('.dismiss-button'),
    'explore_groups_landing_dismissed',
  );
  exploreGroupsLanding.toggle();
});
