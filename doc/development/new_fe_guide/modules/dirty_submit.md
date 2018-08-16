# Dirty Submit

> [Introduced][ce-21115] in GitLab 11.3.  
> [dirty_submit][dirty-submit]

## Summary

Form submits are disabled and default submission behaviour is prevented until any of the form's inputs have their value changed.

## Usage

Import and instantiate `DirtySubmit`, passing the constructor a form element.
Call `DirtySubmit.prototype.init`.

Form submission will be disabled until one of the input's values changes from the value it had when `DirtySubmit.prototype.init` was called.

```js
import DirtySubmit from './dirty_submit/dirty_submit';

document.addEventListener('DOMContentLoaded', () => {
  const dirtySubmit = new DirtySubmit(document.querySelector('form'));
  dirtySubmit.init();
});
```

### Multiple form elements

Use the `DirtySubmitCollection` class to instantiate `DirtySubmit` for multiple forms by passing it's constructor a collection of forms _(`NodeList` or `Array`)_.

It has a handy `DirtySubmitCollection.prototype.init` method that calls `DirtySubmit.prototype.init` for every object in the collection.

```js
import DirtySubmitCollection from './dirty_submit/dirty_submit_collection';

document.addEventListener('DOMContentLoaded', () => {
  const dirtySubmitCollection = new DirtySubmitCollection(document.querySelectorAll('form'));
  dirtySubmitCollection.init();
});
```

## Technical overview

Executing `DirtySubmit.prototype.init` will store the value of each form input as their `data-dirty-submit-original-value` attribute value. It also disables submission and registers an `input` event listener to handle input element value updates.

When an `input` event reaches the form element provided at construction, `DirtySubmit.prototype.updateDirtyInput` is invoked.
If the input element's current value is unequal to it's `data-dirty-submit-original-value` value, the input element's `name` attribute value is stored in the `DirtySubmit.prototype.dirtyInputs` array.
Alternatively, if the values are equal, the input element's `name` will be removed from the array and `DirtySubmit.prototype.toggleSubmission` will be called, which will disable submission if the `DirtySubmit.prototype.dirtyInputs` array is empty and enable submission if it is not.

Currently handles `input`, `textarea` and `select` elements.

Note: The values of `radio` and `checkbox` inputs are read from their `checked` attribute rather than their `value` attribute.

[ce-21115]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21115
[dirty-submit]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/dirty_submit/