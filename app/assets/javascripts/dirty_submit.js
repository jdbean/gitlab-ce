import _ from 'underscore';

function isCheckable(input) {
  return input.type === 'checkbox' || input.type === 'radio';
}

function currentValue(input) {
  return isCheckable(input) ? input.checked.toString() : input.value;
}

function setIsDirty(input) {
  const dirtySubmitInput = input;
  const isDirty = input.dataset.dirtySubmitOriginalValue !== currentValue(input);

  dirtySubmitInput.dataset.isDirty = isDirty;

  return isDirty;
}

function handleDirtyInput(event, form, inputs, submit) {
  let isDirty = false;
  const input = event.target;
  const dirtySubmit = submit;

  if (!input.dataset.dirtySubmitOriginalValue) return;

  if (input.type === 'radio') {
    form.querySelectorAll(`input[type=radio][name="${input.name}"`).forEach(radio => {
      if (!isDirty) isDirty = setIsDirty(radio);
    });
  } else {
    isDirty = setIsDirty(input);
  }

  dirtySubmit.disabled = !isDirty;
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
