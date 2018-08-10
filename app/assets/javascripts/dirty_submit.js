export default function initDirtySubmit(form) {
  const submit = form.querySelector('.js-dirty-submit');
  submit.disabled = true;

  function enableSubmit() {
    submit.disabled = false;

    this.removeEventListener('input', enableSubmit);
  }

  form.addEventListener('input', enableSubmit);
}
