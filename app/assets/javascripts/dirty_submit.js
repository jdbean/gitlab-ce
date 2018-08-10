function disableSubmitIfDirty(inputs, submit) {
  const dirtySubmit = submit;
  dirtySubmit.disabled = !inputs.some(input => input.dataset.isDirty === 'true');
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

export default function initDirtySubmit(form) {
  const inputs = Array.prototype.slice.call(form.querySelectorAll('input, textarea'));
  const submit = inputs.find(input => input.classList.contains('js-dirty-submit'));

  submit.disabled = true;

  inputs.forEach(input => {
    const dirtySubmitInput = input;

    dirtySubmitInput.dataset.dirtySubmitOriginalValue = currentValue(input);
    dirtySubmitInput.dataset.isDirty = false;
  });

  form.addEventListener('input', event => {
    const input = event.target;
    if (!input.dataset.dirtySubmitOriginalValue) return;

    if (input.type === 'radio') {
      const relatedInputs = Array.prototype.slice.call(
        form.querySelectorAll(`input[type=radio][name="${input.name}"`),
      );
      relatedInputs.forEach(setIsDirty);
    } else {
      setIsDirty(input);
    }

    disableSubmitIfDirty(inputs, submit);
  });
}

export function initDirtySubmitMulti(forms) {
  forms.forEach(initDirtySubmit);
}
