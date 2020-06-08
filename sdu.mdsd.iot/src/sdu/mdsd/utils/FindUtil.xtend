package sdu.mdsd.utils

import sdu.mdsd.ioT.Device
import java.util.ArrayList
import java.util.List

class FindUtil {
		
	/*
	 * Finds all of a given type within a device
	 */
	def static <E> findRecursive(Device device, Class<E> cls){findRecursive(device, cls, new ArrayList<E>())}
	
	/*
	 * Finds all of a given type within a device
	 */
	def static <E> List<E> findRecursive(Device device, Class<E> cls, List<E> found) {
		// Check device
		found.addAll(device.eAllContents.filter(cls).toList)
		
		// Check extending
		device.extending.forEach[a|a.findRecursive(cls, found)]
		return found
	}
}