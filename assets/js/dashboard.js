$(document).ready(function() {

    
})

function createEvent() {
    // TODO: handle event creations
    // should add event to list on dashboard
    // and to database via ajax
}

function createStudent() {
    let $form = $('form#newStudentPopup')
    let name = $form.find('#studentName').val().trim()
    let gender = parseInt($form.find('#studentGender').val())
    let avatar = $form.find('#studentAvatar').get(0).files[0]
    
    if (name.length == 0) {
        showToast('Student name must contain alphanumeric characters.')
        return false
    }
    
    let formData = new FormData()
    formData.append('file', avatar)
    $.ajax({
        url: '/upload/student-avatar',
        type: 'POST',
        data: formData,
        cache: false,
        contentType: false,
        processData: false,
        
        success: res => {
            console.log(res)
            // $form.get(0).reset()
            // TODO: Insert student into database if upload is successfull.
        },
        
        error: res => {
            console.error(res)
        }
    })
    
    $(window).click()
}