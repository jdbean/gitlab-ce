<script>
import _ from 'underscore';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf, __ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    deleteWikiUrl: {
      type: String,
      required: true,
      default: '',
    },
    pageTitle: {
      type: String,
      required: true,
      default: '',
    },
    csrfToken: {
      type: String,
      required: true,
      default: '',
    },
  },
  computed: {
    triggerButtonTitle() {
      return __('Delete');
    },
    message() {
      return s__('WikiPageConfirmDelete|Are you sure you want to delete this page?');
    },
    title() {
      return sprintf(
        s__('WikiPageConfirmDelete|Delete page %{pageTitle}?'),
        {
          pageTitle: _.escape(this.pageTitle),
        },
        false,
      );
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal-ui
    :title="title"
    :ok-title="s__('WikiPageConfirmDelete|Delete page')"
    modal-id="delete-wiki-modal"
    title-tag="h4"
    ok-variant="danger"
    class="d-inline-block"
    @ok="onSubmit"
  >
    <template
      slot="modalTrigger"
      slot-scope="{ toggle }"
    >
      <button
        type="button"
        class="btn btn-danger"
        @click="toggle()"
      >
        {{ triggerButtonTitle }}
      </button>
    </template>
    {{ message }}
    <form
      ref="form"
      :action="deleteWikiUrl"
      method="post"
      class="js-requires-input"
    >
      <input
        ref="method"
        type="hidden"
        name="_method"
        value="delete"
      />
      <input
        :value="csrfToken"
        type="hidden"
        name="authenticity_token"
      />
    </form>
  </gl-modal-ui>
</template>
