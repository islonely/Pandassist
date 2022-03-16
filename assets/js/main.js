$(document).ready(function() {

    $.extend(
    {
        redirectPost: function(location='#', args={})
        {
            var form = ''
            $.each( args, function( key, value ) {
                value = value.split('"').join('\"')
                form += '<input type="hidden" name="'+key+'" value="'+value+'">'
            })
            $('<form action="' + location + '" method="POST">' + form + '</form>').appendTo($(document.body)).submit()
        }
    })

    function isEmailValid($email) {
        if ($email.prop('validity').valid) {
            $email.removeClass('border-red-500')
            $email.addClass('border-green-400')
            return true
        } else {
            $email.removeClass('border-green-400')
            $email.addClass('border-red-500')
            return false
        }
    }
    
    function isPasswordValid(password) {
        if (password.length < 12) {
            return false
        }
        // TODO: require more strict password requirements
        return true
    }

    $('form#registerForm').on('submit', function(evt) {
        evt.preventDefault()
        let $submitBttn = $(this).find('button')
        $submitBttn.prop('disabled', true)
        
        let $username = $(this).find('#username')
        let $name = $(this).find('#name')
        let $email = $(this).find('#email')
        let $password = $(this).find('#password')
        let $confirmPassword = $(this).find('#confirmPassword')
        
        if ($username.val() != $username.val().trim()) {
            let cont = confirm('A username cannot start or end with whitespace. Automatically changing "'  + $username.val() + '" to "' + $username.val().trim() + '". Is this alright?')
            if (!cont) return false
        }
        if ($name.val() != $name.val().trim()) {
            let cont = confirm('Your name cannot start or end with whitespace. Automatically changing "' + $name.val() + '" to "' + $name.val().trim() + '". Is this alright?')
            if (!cont) return false
        }
        let validEmail = isEmailValid($email)
        if (!validEmail) {
            alert('The email provided is invalid. Please format as someone@example.com.')
            return false
        }
        let validPassword = isPasswordValid($password.val())
        if (!validPassword) {
            alert('The password provided is invalid. A password must be 12 characters long.')
            return false
        }
        if ($password.val() != $confirmPassword.val()) {
            alert('Password and Confirm Password fields do not match.')
            return false
        }
        
        $.ajax({
            url: '/login',
            method: 'post',
            dataType: 'json',
            data: {
                action: 'register',
                username: $username.val().trim(),
                name: $name.val().trim(),
                email: $email.val().trim(),
                password: $password.val()
            },
            
            success: function(response) {
                console.log(response)
            },
            
            error: function(response) {
                console.error(response)
            }
        })
    })
})