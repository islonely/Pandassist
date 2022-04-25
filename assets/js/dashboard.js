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
    let gender = $form.find('#studentGender').val()
    let files = $form.find('#studentAvatar').get(0)
    let avatar = (files.length > 0) ? file.files[0] : null
    let filepath;
    if (avatar == null) {
        if (gender == '0') {
            filepath = '/assets/img/students/profile-default-male.png'
        } else {
            filepath = '/assets/img/students/profile-default-female.png'
        }
    } else {
        filepath = null
    }
    
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
        
        xhr: function() {
            let xhr = new XMLHttpRequest()
            
            xhr.upload.addEventListener('progress', function(evt) {
                let x = $('#uploadPercent')
                if (evt.lengthComputable) {
                    $('.spinner').css({right: '12px'})
                    let percentComplete = parseInt(evt.loaded / evt.total * 100)
                    window.uploadPercent = setInterval(() => { 
                        if (parseInt(x.text()) < percentComplete) {
                            x.text(parseInt(x.text()) + 1)
                        }
                    }, 10)
                    
                    if (percentComplete == 100) {
                        setTimeout(function() {
                            clearInterval(window.uploadPercent)
                            $('.spinner').css({right: '-100px'})
                        }, 2000)
                    }
                }
            }, false)
            return xhr
        },
        
        success: res => {
            console.log(res)
            if (res.error) {
                showToast(res.message)
            } else {
                filepath = (filepath == null) ? res.data.path : filepath
                $.ajax({
                    url: '/insert/students',
                    type: 'POST',
                    data: JSON.stringify({
                        name: name,
                        gender: gender,
                        avatar_path: filepath
                    }),
                    dataType: 'json',
                    contentType: 'application/json',
                    
                    success: res => {
                        console.log(res)
                        $form.get(0).reset()
                        showToast(res.message)
                    },
                    
                    error: res => {
                        console.error(res)
                        
                    }
                })
            }
        },
        
        error: res => {
            console.error(res)
        }
    })
    
    $(window).click()
}