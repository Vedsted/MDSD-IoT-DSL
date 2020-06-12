package sdu.mdsd.tests

import org.junit.jupiter.api.Test
import com.google.inject.Inject
import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import sdu.mdsd.ioT.Model
import sdu.mdsd.ioT.IoTPackage
import sdu.mdsd.validation.IoTValidator

@ExtendWith(InjectionExtension)
@InjectWith(IoTInjectorProvider)
class IoTValidationAbstractDevicesTest {
	
	@Inject extension ParseHelper<Model>
	@Inject extension ValidationTestHelper
	
	@Test
	def testDeviceExtendsItself() {
		val model = '''
					abstract edge device B extends B { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.HIERARCHY_CYCLE
		)
	}
	
	@Test
	def testDeviceExtendsNonAbstractDevice() {
		val model = '''
					edge device A { }
					abstract edge device B extends A { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.EXTENDS_NON_ABSTRACT_DEVICE
		)
	}
	
	@Test
	def testDeviceExtendedDeviceNotOfSameType1() {
		val model = '''
					abstract edge device A { }
					abstract fog device B extends A { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.EXTENDED_DEVICE_NOT_OF_SAME_TYPE
		)
	}
	
	@Test
	def testDeviceExtendedDeviceNotOfSameType2() {
		val model = '''
					abstract edge device A { }
					abstract cloud device B extends A { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.EXTENDED_DEVICE_NOT_OF_SAME_TYPE
		)
	}
	
	@Test
	def testDeviceExtendedDiamondOrCyclic1() {
		val model = '''
					abstract edge device A extends C { }
					abstract edge device B extends A { }
					abstract edge device C extends B { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.DIAMOND_PROBLEM
		)
	}
	
	@Test
	def testDeviceExtendedDiamondOrCyclic2() {
		val model = '''
					abstract edge device A extends { }
					abstract edge device B extends A { }
					abstract edge device C extends A { }
					abstract edge device D extends B, C { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.DIAMOND_PROBLEM
		)
	}
	
	@Test
	def testDeviceExtendedDiamondOrCyclic3() {
		val model = '''
					abstract edge device A { }
					abstract edge device B extends A { }
					abstract edge device C extends A, B { }
					'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.DIAMOND_PROBLEM
		)
	}
	
	@Test
	def testDuplicateVarOrListInHierarchy1() {
		val model = '''
		abstract edge device AbstractBase {
			var basevar = 0
			var NIL // THIS IS DUPLICATE
		}
		
		abstract edge device AbstractLightSensor {
			list lightLevels
			var lightLevel
			var lower = 90
			var upper = 300
			var NIL // THIS IS DUPLICATE
		}
		
		abstract edge device AbstractLEDActuator {
			var turnOnLED = false
		}
		
		edge device Harvester extends AbstractLightSensor, AbstractLEDActuator, AbstractBase {
			var isEmpty
		}
		'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.DUPLICATE_VAR_OR_LIST
		)
	}
	
	@Test
	def testDuplicateVarOrListInHierarchy2() {
		val model = '''
		abstract edge device AbstractBase {
			var basevar = 0
		}
		
		abstract edge device AbstractLightSensor {
			list lightLevels
			var lightLevel
			var lower = 90
			var upper = 300
			var NIL // THIS IS DUPLICATE
		}
		
		abstract edge device AbstractLEDActuator {
			var turnOnLED = false
		}
		
		edge device Harvester extends AbstractLightSensor, AbstractLEDActuator, AbstractBase {
			var isEmpty
			var NIL // THIS IS DUPLICATE
		}
		'''.parse
		model.assertError(IoTPackage.eINSTANCE.device,
						  IoTValidator.DUPLICATE_VAR_OR_LIST
		)
	}
}