package sdu.mdsd.tests

import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.InjectWith
import com.google.inject.Inject
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import sdu.mdsd.ioT.Model
import org.junit.jupiter.api.Test
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.validation.IoTValidator

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class IoTValidationWarningsTest {
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def testVarOrListNameUpperCase() {
		val model = '''
					abstract edge device A {
						var Myvar = 0
					}
					'''.parse
		model.assertWarning(IoTPackage.eINSTANCE.varOrList,
							IoTValidator.VAR_OR_LIST_UPPER_CASE
		)
	}
	
	@Test
	def testDeviceNameLowerCase() {
		val model = '''
					abstract edge device a { }
					'''.parse
		model.assertWarning(IoTPackage.eINSTANCE.device,
							IoTValidator.DEVICE_NAME_LOWER_CASE
		)
	}
}