import _ from 'underscore';

function disableSubmitIfDirty(inputs, submit) {
  const dirtySubmit = submit;
  dirtySubmit.disabled = !Array.prototype.slice
    .call(inputs)
    .some(input => input.dataset.isDirty === 'true');
}

function isCheckable(input) {
  return input.type === 'checkbox' || input.type === 'radio';
}

function currentValue(input) {
  return isCheckable(input) ? input.checked.toString() : input.value;
}

function setIsDirty(input) {
  const dirtySubmitInput = input;
  dirtySubmitInput.dataset.isDirty = input.dataset.dirtySubmitOriginalValue !== currentValue(input);
}

function handleDirtyInput(event, form, inputs, submit) {
  const input = event.target;
  if (!input.dataset.dirtySubmitOriginalValue) return;

  if (input.type === 'radio') {
    form.querySelectorAll(`input[type=radio][name="${input.name}"`).forEach(setIsDirty);
  } else {
    setIsDirty(input);
  }

  disableSubmitIfDirty(inputs, submit);
}

const throttledHandleDirtyInput = _.throttle(handleDirtyInput, 400);

function initDirtySubmitForm(form) {
  const inputs = form.querySelectorAll('input, textarea, select');
  const submit = form.querySelector('.js-dirty-submit');

  submit.disabled = true;

  inputs.forEach(input => {
    const dirtySubmitInput = input;

    dirtySubmitInput.dataset.dirtySubmitOriginalValue = currentValue(input);
    dirtySubmitInput.dataset.isDirty = false;
  });

  form.addEventListener('input', event => throttledHandleDirtyInput(event, form, inputs, submit));
}

export default function initDirtySubmit(formOrForms) {
  const forms = Array.isArray(formOrForms) ? formOrForms : new Array(formOrForms);

  forms.forEach(initDirtySubmitForm);
}
