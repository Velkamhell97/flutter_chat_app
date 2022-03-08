import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
// import 'dart:io';

import '../providers/providers.dart';
import '../services/services.dart';
import '../styles/styles.dart';


class RegisterForm extends StatelessWidget {
  const RegisterForm({Key? key}) : super(key: key);

  static const roles = <String>['CLIENT_ROLE', 'ADMIN_ROLE'];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthServices>(context, listen: false);
    final form = Provider.of<RegisterFormProvider>(context);
    
    final loading = form.loading;
    final show    = form.show;
    final body    = form.body;
    final error   = form.error;

    return Form(
      key: form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //-------------------------------
          // Name Field
          //-------------------------------
          TextFormField(
            initialValue: body['name'],
            textCapitalization: TextCapitalization.words,
            decoration: InputStyles.authInputStyle.copyWith(
              hintText: 'Name',
              prefixIcon: const Icon(Icons.person_outline)
            ),
            onChanged: (value) => body['name'] = value,
            validator: (value) => (value ?? '').isNotEmpty ? null : 'The name is required',
          ),

          const SizedBox(height: 20.0),

          //-------------------------------
          // Email Field
          //-------------------------------
          TextFormField(
            initialValue: body['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: InputStyles.authInputStyle.copyWith(
              hintText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined)
            ),
            onChanged: (value) => form.body['email'] = value,
            validator: (value) => EmailValidator.validate(value ?? '') ? null : 'Enter a valid email'
           ),

          const SizedBox(height: 20.0),
          
          //-------------------------------
          // Password Field
          //-------------------------------
          TextFormField(
            obscureText: !show,
            decoration: InputStyles.authInputStyle.copyWith(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: GestureDetector(
                onTap: () => form.show = !show,
                child: show ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
            ),
            onChanged: (value) => body['password'] = value,
            validator: (value) => (value ?? '').length > 5 ? null : 'Password must contain at least 6 characters',
          ),

          const SizedBox(height: 20.0),
          
          //-------------------------------
          // Role Field
          //-------------------------------
          // DropdownButtonFormField<String>(
          //   decoration: InputStyles.authInputStyle.copyWith(
          //     hintText: 'Role',
          //     prefixIcon: const Icon(Icons.recent_actors_outlined)
          //   ),
          //   items: roles.map((rol) => DropdownMenuItem<String>(value: rol, child: Text(rol))).toList(), 
          //   onTap: () => FocusScope.of(context).unfocus(),
          //   onChanged: (value) => body['role'] = value!,
          //   validator: (value) => (value ?? '').isNotEmpty ? null : 'The role is required',
          // ),

          const SizedBox(height: 20.0),
          
          //-------------------------------
          // Avatar Field
          //-------------------------------
          // InkWell( //-Algunas veces no necesita el material
          //   borderRadius: BorderRadius.circular(10.0),
          //   onTap: () async {
          //     final XFile? image = await  ImagePicker().pickImage(source: ImageSource.gallery);

          //     if(image != null){
          //       form.image = image.path;
          //     }
          //   },
          //   child: _UploadBox(image: form.image) 
          // ),

          const SizedBox(height: 20.0),

          //------------------------------------
          // Error Text
          //------------------------------------
          if(error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(error.details.msg, style: TextStyles.formError, textAlign: TextAlign.center),
            ),

          //-------------------------------
          // Submit Button
          //-------------------------------
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 15.0)
            ),
            onPressed: () async {
              if(loading) return;
              form.error = null;
              FocusScope.of(context).unfocus();

              if(form.validate()){
                form.loading = true;

                final error = await auth.signup(data: body);

                if(error == null){
                  // Navigator.of(context).pushReplacementNamed('/users');
                  Navigator.of(context).pushNamedAndRemoveUntil('/users', (Route route) => false);
                } else {
                  form.error = error;
                  form.loading = false;
                }
              }
            }, 
            child: loading 
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Register', style: TextStyles.button)
          )
        ],
      ),
    );
  }
}

//-Para subir imagenes
// class _UploadBox extends StatelessWidget {
//   final String? image;

//   const _UploadBox({Key? key, required this.image}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final upload = image != null;

//     return Container(
//       clipBehavior: Clip.antiAlias,
//       height: 50,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey),
//         borderRadius: BorderRadius.circular(10.0)
//       ),
//       child: Row(
//         children: [
//           Flexible(
//             flex: 1,
//             child: SizedBox.expand(
//               child: upload ? Image.file(File(image!), fit: BoxFit.fitWidth) : const Icon(Icons.image),
//             ),
//           ),
//           const VerticalDivider(color: Colors.grey, thickness: 2, width: 0),
//           Flexible(
//             flex: 3,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 upload ? const Icon(Icons.check_circle_outline) : const Icon(Icons.upload),
//                 const SizedBox(width: 10),
//                 upload ? const Text('Image Uploaded') :const Text('Upload Image'),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }