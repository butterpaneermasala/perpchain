import React from 'react';
import { Box, Heading, Text, VStack, Button, Input } from '@chakra-ui/react';

export default function Trading() {
  // TODO: Add hooks for open/close/view positions
  return (
    <Box p={8} bg="white" borderRadius="lg" boxShadow="md">
      <Heading size="lg" mb={4}>Trading</Heading>
      <VStack align="start">
        <Text>Position: <b>--</b></Text>
        <Input placeholder="Size" maxW="200px" />
        <Button colorScheme="blue">Open Position</Button>
        <Button colorScheme="orange">Close Position</Button>
      </VStack>
    </Box>
  );
} 