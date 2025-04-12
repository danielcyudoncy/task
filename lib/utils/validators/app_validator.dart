class AppValidator {
  // Validate text field for non-empty value
  static String? validateTextState(String? text) {
    if (text == null || text.isEmpty) {
      return "This field cannot be empty!";
    } else {
      return null;
    }
  }

  // Validate name for required value and minimum length
  static String? validateName(String? name, String titleName) {
    if (name == null || name.isEmpty) {
      return "$titleName is required!";
    } else if (name.length <= 3) {
      return "$titleName should be at least 4 characters";
    } else {
      return null;
    }
  }

  // Validate phone number for required value and correct length (assumes 11 digits)
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return "Phone Number is required!";
    } else if (phone.length != 11) {
      return "Invalid Phone Number! It must be 11 digits.";
    } else {
      return null;
    }
  }

  // Validate email with regex
  static String? validateEmail(String? email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', // Improved email regex
    );

    if (email == null || email.isEmpty) {
      return "Email Address is required!";
    } else if (!emailRegExp.hasMatch(email)) {
      return "Invalid Email Address!";
    } else {
      return null;
    }
  }

  // Validate password for complexity
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Password is required.";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters long";
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?:{}|<>]'))) {
      return "Password must contain at least one special character.";
    }

    return null;
  }

  // Confirm password match
  static String? confirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword != password) {
      return "Password and Confirm Password do not match";
    } else {
      return null;
    }
  }
}
