import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import projectMultiSelect from '~/project_multi_select';
import Api from '~/api';

const FIXTURE_PATH = 'static/project_multi_select.html.raw';
const TEST_PROJECTS = [
  {
    id: 1,
    name: 'Lorem',
  },
  {
    id: 2,
    name: 'Ipsum',
  },
  {
    id: 3,
    name: 'Dolar',
  },
  {
    id: 4,
    name: 'Sit',
  },
];

describe('project_multi_select', () => {
  preloadFixtures(FIXTURE_PATH);

  let mock;
  let $input;
  let projectsResponse;

  beforeEach(() => {
    loadFixtures(FIXTURE_PATH);

    $input = $('#project_ids');

    mock = new MockAdapter(axios);
    mock.onGet(Api.buildUrl(Api.projectsPath))
      .reply(() => projectsResponse);

    projectsResponse = new Promise(() => {});
  });

  afterEach(() => {
    mock.restore();
  });

  describe('projectMultiSelect', () => {
    let $select2Container;

    beforeEach(() => {
      projectMultiSelect();

      $select2Container = $input.select2('container');
    });

    it('adds hidden inputs on value change', () => {
      const vals = ['1', '2', '7'];
      const $form = $('form');

      $input.val(vals);
      $form.on('submit', e => e.preventDefault());
      $form.submit();

      const inputVals = $input.parent()
        .find('input[name="fixture[project_ids][]"]')
        .toArray()
        .map(x => $(x).attr('value'));

      expect(inputVals).toEqual(vals);
    });

    it('adds icon', () => {
      expect($select2Container.children('.input-icon-right')).toHaveLength(1);
    });

    it('hides icon on open', () => {
      $input.select2('open');

      expect($select2Container).toHaveClass('hide-input-icon');
    });

    it('shows icon on close', () => {
      $input.select2('open');

      $input.select2('close');

      expect($select2Container).not.toHaveClass('hide-input-icon');
    });

    it('queries and displays projects', (done) => {
      projectsResponse = Promise.resolve([200, TEST_PROJECTS]);

      $input.select2('open');

      setTimeout(() => {
        const projectTitles = $('#select2-drop')
          .find('.project-title')
          .toArray()
          .map(x => x.textContent);

        expect(projectTitles).toEqual(TEST_PROJECTS.map(x => x.name));

        done();
      }, 50);
    });
  });
});
