$(document).ready(function() {

    // $.extend(
    // {
    //     redirectPost: function(location='#', args={})
    //     {
    //         var form = ''
    //         $.each( args, function( key, value ) {
    //             value = value.split('"').join('\"')
    //             form += '<input type="hidden" name="'+key+'" value="'+value+'">'
    //         })
    //         $('<form action="' + location + '" method="POST">' + form + '</form>').appendTo($(document.body)).submit()
    //     }
    // })

    String.prototype.hasNumber = function() {
        if (this === undefined) return false
        return /\d/.test(this)
    }

    String.prototype.hasSymbol = function() {
        if (this === undefined) return false
        let symbols = Array.from('!@#$%^&*()_+-=~`{}[]:;\\|\'"?/,.<>')
        let str = Array.from(this)
        for (let i = 0; i < str.length; i++) {
            if (symbols.includes(str[i])) {
                return true
            }
        }
        return false
    }

    function isEmailValid($email) {
        // builtin email checker says empty string is okay?
        if ($email.val() === '') {
            showToast('Email cannot be empty.')
            return false
        }
        if ($email.prop('validity').valid) {
            return true
        } else {
            showToast('Malformatted email provided.')
            return false
        }
    }

    function isPhoneValid(phone) {
        let usphone = /^(\+0?1\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$/
        // The plan is to support US customers only, but this is just in case
        // plans change and business is successful.
        //let globalphone = /^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$/

        if (phone === undefined) return false

        if (!usphone.test(phone)) {
            showToast('Malformatted phone number.')
            return false
        }
        return true
    }
    
    function isPasswordValid(password) {
        if (password === '') {
            showToast('Password cannot be empty.')
            return false
        }
        if (password.length < 12) {
            showToast('Password must be 12 character long.')
            return false
        }
        
        let hasSymbol = password.hasSymbol()
        let hasNumber = password.hasNumber()
        let eqTrim = password == password.trim()

        if (!hasSymbol) {
            showToast('Password must contain a special character.')
            return false
        }
        if (!hasNumber) {
            showToast('Password must contain a number.')
            return false
        }
        if (!eqTrim) {
            showToast('Password cannot start or end with whitespace.')
            return false
        }

        return true
    }

    $('form#loginForm').on('submit', function(evt) {
        evt.preventDefault()
        let $email = $(this).find('#emailLogin')
        let $password = $(this).find('#passwordLogin')
        let $rememberMe = $(this).find('#rememberMeLogin')

        $.ajax({
            url: '/login',
            method: 'post',
            dataType: 'json',
            contentType: 'application/json',
            data: JSON.stringify({
                action: 'login',
                email: $email.val().trim(),
                password: $password.val(),
                remember_me: $rememberMe.is(':checked')
            }),
            
            success: function(response) {
                if (!response.error) {
                    if (response.message == 'Incorrect username or password.') {
                        showToast(response.message)
                    } else {
                        window.location.replace('/dashboard')
                    }
                } else {
                    showToast(response.message)
                }
            },
            
            error: function(response) {
                console.error(response)
            }
        })
    })

    $('form#registerForm').on('submit', function(evt) {
        evt.preventDefault()
        // let $submitBttn = $(this).find('button')
        // $submitBttn.prop('disabled', true)
        
        let $username = $(this).find('#username')
        let $name = $(this).find('#name')
        let $email = $(this).find('#email')
        let $phone = $(this).find('#phone')
        let $password = $(this).find('#password')
        let $rememberMe = $(this).find('#rememberMe')
        let $confirmPassword = $(this).find('#confirmPassword')
        
        if ($username.val() != $username.val().trim()) {
            let cont = confirm('A username cannot start or end with whitespace. Automatically changing "'  + $username.val() + '" to "' + $username.val().trim() + '". Is this alright?')
            if (!cont) return false
        }
        if ($name.val() != $name.val().trim()) {
            let cont = confirm('Your name cannot start or end with whitespace. Automatically changing "' + $name.val() + '" to "' + $name.val().trim() + '". Is this alright?')
            if (!cont) return false
        }
        if (!isEmailValid($email)) return false
        if (!isPhoneValid($phone.val())) return false
        if (!isPasswordValid($password.val())) return false
        if ($password.val() != $confirmPassword.val()) {
            showToast('Password and Confirm Password fields do not match.')
            return false
        }
        
        $.ajax({
            url: '/login',
            method: 'post',
            dataType: 'json',
            contentType: 'application/json',
            data: JSON.stringify({
                action: 'register',
                username: $username.val().trim(),
                name: $name.val().trim(),
                email: $email.val().trim(),
                phone: $phone.val().trim(),
                remember_me: $rememberMe.is(':checked'),
                password: $password.val()
            }),
            
            success: function(response) {
				showToast(response.message)
                if (!response.error) {
                    window.location.replace('/dashboard')
                }
            },
            
            error: function(response) {
                console.error(response)
            }
        })
    })
})