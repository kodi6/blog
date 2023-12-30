const closeAllToolbars = () => {
    document.querySelectorAll(".tox-toolbar__overflow").forEach(el => el.remove())
  }
  
  export default {
    mounted() {
      const elID = this.el.id
      const fieldName = this.el.dataset.field;
  
      tinymce.init({
        selector: `#${elID}`,
        height: 300,
        plugins: [
          'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
          'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
          'insertdatetime', 'media', 'table', 'help', 'wordcount'
        ],
        external_plugins: {
          'formula': '/images/tinymce-formula/plugin.min.js'
        },
        toolbar: 'undo redo | blocks | ' +
          'bold italic backcolor image | alignleft aligncenter ' +
          'alignright alignjustify | bullist numlist outdent indent | ' +
          'formula | removeformat | help',
        content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:16px }',
        placeholder: 'Type something here...',
      });
  
      const editor = tinymce.get(elID)
  
      const pushEventHandler = () => {
        var content = editor.getContent();
        //This sends the event of
        // def handle_event("text-editor", %{"title" => title, "description" => description}, socket) do
        this.pushEventTo(this.el, "post", {
            title: param
        });
      }
  
      const onChangeHandler = () => {
        closeAllToolbars()
        pushEventHandler()
      }
  
      this.handleEvent("tinymce_reset", () => {
        editor.resetContent()
        pushEventHandler()
      });
  
      editor.on('keyup', onChangeHandler);
      editor.on('change', onChangeHandler);
    },
    destroyed() {
      // console.log("Destroyed TinyMCE....")
      closeAllToolbars()
      var editor = tinymce.get(this.el.id);
      if (editor) {
        editor.remove();
      }
    }
  };
  