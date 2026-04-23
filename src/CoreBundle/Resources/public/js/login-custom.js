(function (global) {
  'use strict';

  function togglePasswordVisibility(toggle, passwordField) {
    if (!toggle || !passwordField) {
      return;
    }

    var reveal = passwordField.type === 'password';
    passwordField.type = reveal ? 'text' : 'password';
    toggle.setAttribute('aria-pressed', String(reveal));
    toggle.setAttribute('aria-label', reveal ? 'Hide password' : 'Show password');
  }

  function resolvePasswordField(toggle) {
    var scopedField = null;

    if (toggle && typeof toggle.closest === 'function') {
      var container = toggle.closest('.InputContainer');
      if (container) {
        scopedField = container.querySelector('#password_input, input[name="_password"], input[type="password"], input[type="text"]');
      }
    }

    return scopedField || document.getElementById('password_input');
  }

  function initPimLoginForm(inputs, submitButton, form) {
    var fields = Array.isArray(inputs) ? inputs.filter(Boolean) : [];
    var submit = submitButton || null;
    var loginForm = form || document.querySelector('form.Form');
    function isValid(field) {
      return !!field && typeof field.value === 'string' && field.value.trim().length > 0;
    }

    function updateSubmitState() {
      if (!submit || fields.length === 0) {
        return;
      }

      var ready = fields.every(isValid);
      submit.disabled = !ready;
      submit.setAttribute('aria-disabled', String(!ready));
    }

    fields.forEach(function (field) {
      field.addEventListener('input', updateSubmitState);
      field.addEventListener('blur', updateSubmitState);
    });

    if (loginForm && submit) {
      loginForm.addEventListener('submit', function () {
        submit.disabled = true;
        submit.setAttribute('aria-disabled', 'true');
      });
    }

    updateSubmitState();
  }

  document.addEventListener('click', function (event) {
    var target = event.target;
    var toggle = target && typeof target.closest === 'function' ? target.closest('.password-toggle') : null;

    if (!toggle) {
      return;
    }

    event.preventDefault();
    togglePasswordVisibility(toggle, resolvePasswordField(toggle));
  });

  global.initPimLoginForm = initPimLoginForm;
})(window);
