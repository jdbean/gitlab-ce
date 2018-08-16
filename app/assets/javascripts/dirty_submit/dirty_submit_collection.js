import DirtySubmit from './dirty_submit';

export default class DirtySubmitCollection {
  constructor(formOrForms) {
    const isCollection = formOrForms instanceof NodeList || formOrForms instanceof Array;
    this.forms = isCollection ? formOrForms : new Array(formOrForms);

    this.dirtySubmits = [];
    this.forms.forEach(form => this.dirtySubmits.push(new DirtySubmit(form)));
  }

  init() {
    this.dirtySubmits.forEach(dirtySubmit => dirtySubmit.init());
  }
}
