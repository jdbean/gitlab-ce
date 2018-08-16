import _ from 'underscore';

export default class DirtySubmit {
  constructor(form) {
    this.form = form;
    this.dirtyInputs = [];
  }

  init() {
    this.inputs = this.form.querySelectorAll('input, textarea, select');
    this.submits = this.form.querySelectorAll('input[type=submit], button[type=submit]');

    this.inputs.forEach(DirtySubmit.initInput);
    this.submits.forEach(submit => submit.setAttribute('disabled', ''));

    this.registerListener();
  }

  registerListener() {
    const throttledUpdateDirtyInput = _.throttle(event => this.updateDirtyInput(event), 400);
    this.form.addEventListener('input', throttledUpdateDirtyInput);
  }

  updateDirtyInput(event) {
    const input = event.target;

    if (!input.dataset.dirtySubmitOriginalValue) return;

    this.updateDirtyInputReference(input);
    this.toggleSubmission(this.dirtyInputs.length === 0);
  }

  updateDirtyInputReference(input) {
    const { name } = input;
    const isDirty = input.dataset.dirtySubmitOriginalValue !== DirtySubmit.inputCurrentValue(input);
    const indexOfInputName = this.dirtyInputs.indexOf(name);
    const isAlreadyReferenced = indexOfInputName !== -1;

    if ((isDirty && isAlreadyReferenced) || (!isDirty && !isAlreadyReferenced)) return;

    if (isDirty && !isAlreadyReferenced) this.dirtyInputs.push(name);
    if (!isDirty && isAlreadyReferenced) this.dirtyInputs.splice(indexOfInputName, 1);
  }

  toggleSubmission(isDisabled) {
    this.submits.forEach(submit => {
      submit.disabled = isDisabled; // eslint-disable-line no-param-reassign
    });
  }

  static initInput(input) {
    /* eslint-disable no-param-reassign */
    input.dataset.dirtySubmitOriginalValue = DirtySubmit.inputCurrentValue(input);
    /* eslint-enable no-param-reassign */
  }

  static isInputCheckable(input) {
    return input.type === 'checkbox' || input.type === 'radio';
  }

  static inputCurrentValue(input) {
    return DirtySubmit.isInputCheckable(input) ? input.checked.toString() : input.value;
  }
}
